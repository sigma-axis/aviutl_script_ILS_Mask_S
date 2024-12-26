--[[
MIT License
Copyright (c) 2024 sigma-axis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

https://mit-license.org/
]]

--
-- VERSION: v1.00
--

--------------------------------

local ils = require "InlineScene_S";
local obj, math, tonumber = obj, math, tonumber;

local tmp_name = "cache:ils_mask_s"

-- an upvalue storage of setting values.
local settings = {
	x = 0, y = 0,
	size = -1,
	scale = 1.0,
	angle = 0,
};

local function settings_common(x, y, angle)
	settings.x = math.min(math.max(tonumber(x) or 0, -2000), 2000);
	settings.y = math.min(math.max(tonumber(y) or 0, -2000), 2000);
	settings.angle = math.min(math.max(tonumber(angle) or 0, -720), 720);
end
---マスクの拡大率とぼかし量を記録する．
---@param x number? マスクの位置の X 座標．既定値は 0.
---@param y number? マスクの位置の Y 座標．既定値は 0.
---@param angle number? マスクの回転角度を指定．度数法で時計回りに正．既定値は 0.
---@param scale number? 拡大率を指定．既定値は等倍で 1.0.
local function settings_byscale(x, y, angle, scale)
	settings_common(x, y, angle);
	settings.size = -1;
	settings.scale = math.max(tonumber(scale) or 1.0, 0);
end
---マスクのサイズとぼかし量を記録する．
---@param x number? マスクの位置の X 座標．既定値は 0.
---@param y number? マスクの位置の Y 座標．既定値は 0.
---@param angle number? マスクの回転角度を指定．度数法で時計回りに正．既定値は 0.
---@param size number? マスクのサイズを長辺の長さでピクセル単位で指定．nil だと 等倍指定と同等の効果．
local function settings_bysize(x, y, angle, size)
	local sz = tonumber(size);
	if sz then
		settings_common(x, y, angle);
		settings.size = math.max(sz, 0);
		settings.scale = -1;
	else settings_byscale(x, y, angle, 1.0) end
end

-- wrapper functions for specific filters.
local function invert_alpha() obj.effect("反転", "透明度反転", 1) end
local function apply_blur(radius)
	if radius > 0 then  obj.effect("ぼかし", "範囲", radius) end
end

local function draw(w, h, blur, x, y, angle, scale, metrics)
	if scale >= 0 then
		obj.draw(x, y, 0, scale, metrics.alpha, 0, 0, angle);
	else
		obj.drawpoly(-w / 2, -h / 2, 0, w / 2, -h / 2, 0, w / 2, h / 2, 0, -w / 2, h / 2, 0,
			blur, blur, metrics.w + blur, blur, metrics.w + blur, metrics.h + blur, blur, metrics.h + blur,
			metrics.alpha);
	end
end

---マスク操作を適用する．計算中に tempbuffer を上書きするため，必要ならデータの退避をしておくこと．
---@param name string マスク元画像に利用する "inline scene" の名前 (アルファ値のみが影響).
---@param intensity number マスクの強さを指定. 0.0 で無効，1.0 で通常のマスクとなる. 1.0 を超える値も有効．
---@param blur integer ぼかし量をピクセル単位で指定．
---@param invert boolean マスクを反転するかどうかを指定．
---@param alpha_min boolean false だとアルファ値がマスク元画像との積になる．true だとマスク元画像と比べて小さいほうに揃えられる．
---@param curr_frame boolean? 現在フレームで合成された "inline scene" のみを対象にするかどうかを指定．既定値は `true`.
---@param recall_settings boolean? `settings_byscale` などで指定された設定を有効化する．false の場合は「元のサイズに合わせる」相当の動作．
local function apply(name, intensity, blur, invert, alpha_min, curr_frame, recall_settings)
	-- hereafter in this function, "source" is the image that modifies the alpha channel,
	-- and "target" is the one that is modified.
	-- "source" is only meaningful with its alpha values.

	if intensity <= 0 then return end
	blur = math.min(math.max(blur, 0), 500);

	local cache_name, metrics, status, _ = ils.read_cache(name);
	if not status or (curr_frame and status ~= "new") then return end

	-- retrieve settings.
	local x, y, angle, scale = 0, 0, 0, -1;
	if recall_settings then
		x, y, angle = settings.x, settings.y, settings.angle;
		if settings.scale < 0 then
			scale = settings.size / math.max(metrics.w, metrics.h);
		else scale = metrics.zoom * settings.scale end

		-- adjust the position and rotation center according to the current states.
		local base_cx, base_cy = obj.getvalue("cx"), obj.getvalue("cy");
		x, y = x - obj.ox + obj.cx - base_cx, y - obj.oy + obj.cy - base_cy;
		if ils.offscreen_drawn() then
			-- when off-screen draw is applied, the center is a bit offset.
			x, y = x + obj.x - base_cx, y + obj.y - base_cy;
		end

		-- apply rotation and scaling.
		local src_cx, src_cy = scale * metrics.cx, scale * metrics.cy;
		angle = angle + metrics.rz;
		if angle % 360 ~= 0 then
			local c, s = math.cos(math.pi / 180 * angle), math.sin(math.pi / 180 * angle);
			src_cx, src_cy = c * src_cx - s * src_cy, s * src_cx + c * src_cy;
		end
		x, y = x - src_cx, y - src_cy;
	end

	-- perform buffer operations.
	-- blend buffers two times so the alpha values are
	-- multiplied if alpha_min is false, or minimized if alpha_min is true.
	local w, h = obj.getpixel();
	obj.copybuffer(tmp_name, "obj");
	if invert then
		obj.copybuffer("obj", cache_name);
		apply_blur(blur);

		obj.setoption("dst", "tmp", w, h);
		obj.setoption("blend", 0);
		draw(w, h, blur, x, y, angle, scale, metrics);

		obj.copybuffer("obj", "tmp");
		invert_alpha();

		if alpha_min then
			obj.copybuffer("tmp", tmp_name);
			obj.setoption("blend", "alpha_sub");
		else
			obj.copybuffer("tmp", "obj");
			obj.copybuffer("obj", tmp_name);
			invert_alpha();
		end
		obj.draw();
	else
		if not alpha_min then invert_alpha() end
		obj.copybuffer("tmp", "obj");

		obj.copybuffer("obj", cache_name);
		apply_blur(blur);

		obj.setoption("dst", "tmp");
		obj.setoption("blend", alpha_min and "alpha_sub" or 0);
		draw(w, h, blur, x, y, angle, scale, metrics);
	end
	obj.copybuffer("obj", "tmp");
	if not alpha_min then invert_alpha() end

	obj.copybuffer("tmp", tmp_name);
	obj.setoption("blend", "alpha_sub");
	obj.draw(0, 0, 0, 1, intensity);
	obj.copybuffer("obj", "tmp");

	-- rewind the blend mode.
	obj.setoption("blend", 0);
end


local function equals_any(x, y, ...)
	if y == nil then return false;
	elseif x == y then return true;
	else return equals_any(x, ...) end
end
---直前のフィルタ効果が同じファイルの指定のスクリプトであることを確認する関数．付属の `.anm` 専用の用途・目的．
---@param ... string アニメーション効果名を列挙．
---@return boolean
local function is_former_script(...)
	local s = obj.getoption("script_name", -1, true);
	if s then
		local t = obj.getoption("script_name"):match("@.+$");
		if #t < #s and s:sub(-#t) == t then
			return equals_any(s:sub(1, -#t - 1), ...);
		end
	end
	return false;
end

return {
	settings_byscale = settings_byscale,
	settings_bysize = settings_bysize,

	apply = apply,

	is_former_script = is_former_script,
};

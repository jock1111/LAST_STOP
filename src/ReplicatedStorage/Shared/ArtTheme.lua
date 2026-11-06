-- LAST STOP art direction tokens. Geometry services consume these values rather
-- than scattering unrelated colors throughout the game world.
return {
	Palette = {
		VoidNavy = Color3.fromRGB(17, 24, 32),
		BlueGray = Color3.fromRGB(28, 39, 48),
		Concrete = Color3.fromRGB(65, 73, 78),
		Steel = Color3.fromRGB(101, 113, 120),
		Cyan = Color3.fromRGB(99, 216, 213),
		Amber = Color3.fromRGB(233, 166, 77),
		Alarm = Color3.fromRGB(224, 75, 88),
		OffWhite = Color3.fromRGB(233, 240, 238),
		Rubber = Color3.fromRGB(24, 29, 34),
	},
	-- Poly Haven CC0 maps, uploaded through Studio by gakez007 on 2026-11-03.
	-- Exact inventory IDs are documented in ART_ASSETS.md.
	Pbr = {
		PaintedSteel = { BaseMaterial = Enum.Material.Metal, StudsPerTile = 5, ColorMap = "rbxassetid://137105055040989", NormalMap = "rbxassetid://72038388556893", MetalnessMap = "rbxassetid://80777076182700", RoughnessMap = "rbxassetid://88399395045423" },
		ChippedConcrete = { BaseMaterial = Enum.Material.Concrete, StudsPerTile = 4, ColorMap = "rbxassetid://80959961009929", NormalMap = "rbxassetid://80291856302301", MetalnessMap = "rbxassetid://80777076182700", RoughnessMap = "rbxassetid://77587300776452" },
		MetalPlate = { BaseMaterial = Enum.Material.Metal, StudsPerTile = 5, ColorMap = "rbxassetid://137105055040989", NormalMap = "rbxassetid://72038388556893", MetalnessMap = "rbxassetid://91150503292713", RoughnessMap = "rbxassetid://88399395045423" },
		-- Corroded steel for lab machinery, railings, and flooded-structure surfaces.
		-- Reuses Poly Haven metal_plate maps with a tighter tile read for heavier rust detail.
		CorrodedSteel = { BaseMaterial = Enum.Material.Metal, StudsPerTile = 3, ColorMap = "rbxassetid://137105055040989", NormalMap = "rbxassetid://72038388556893", MetalnessMap = "rbxassetid://91150503292713", RoughnessMap = "rbxassetid://88399395045423" },
		-- Flooded concrete for basin and submerged walkway surfaces.
		-- Reuses Poly Haven chipped_concrete maps with a finer tile read for wet concrete.
		FloodedConcrete = { BaseMaterial = Enum.Material.Concrete, StudsPerTile = 3, ColorMap = "rbxassetid://80959961009929", NormalMap = "rbxassetid://80291856302301", MetalnessMap = "rbxassetid://80777076182700", RoughnessMap = "rbxassetid://77587300776452" },
	-- Containment glass: no PBR maps, uses built-in Glass with tint directly.
	},
}

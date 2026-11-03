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
	-- Source art is held in assets/polyhaven. These entries deliberately remain
	-- empty until their Studio upload IDs are verified under the experience owner;
	-- never ship guessed, private, or borrowed asset IDs.
	Pbr = {
		ChippedConcrete = { BaseMaterial = Enum.Material.Concrete, ColorMap = "", NormalMap = "", MetalnessMap = "", RoughnessMap = "" },
		MetalPlate = { BaseMaterial = Enum.Material.Metal, ColorMap = "", NormalMap = "", MetalnessMap = "", RoughnessMap = "" },
	},
}

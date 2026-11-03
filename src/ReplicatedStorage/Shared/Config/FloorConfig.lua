-- The vertical slice uses three generated, solo-safe room templates.
return {
	RecentRepeatWindow = 2,
	Floors = {
		{
			Id = "Archive",
			Name = "Archive 01: Medical Records",
			Weight = 50,
			ObjectiveType = "Collect",
			Target = 3,
			Prompt = "Recover the medical records.",
			Accent = Color3.fromRGB(73, 212, 210),
		},
		{
			Id = "FloodedLab",
			Name = "Flooded Laboratory",
			Weight = 30,
			ObjectiveType = "Activate",
			Target = 3,
			Prompt = "Restart all three pump systems.",
			Accent = Color3.fromRGB(61, 146, 219),
		},
		{
			Id = "Lockdown",
			Name = "Security Lockdown",
			Weight = 20,
			ObjectiveType = "Activate",
			Target = 3,
			Prompt = "Hack each security terminal.",
			Accent = Color3.fromRGB(225, 78, 78),
		},
	},
}

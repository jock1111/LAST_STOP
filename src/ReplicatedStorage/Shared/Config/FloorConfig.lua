-- One finished authored slice; the old lab/security prototypes are not selected.
return {
	RecentRepeatWindow=2,
	Floors={{Id="Archive",Template="Hospital",Name="Saint Orin / Clinical Archive",
		Weight=100,ObjectiveType="Collect",Target=3,
		Prompt="Recover records from the ward, imaging room, and archive.",
		Accent=Color3.fromRGB(99,216,213)}},
}

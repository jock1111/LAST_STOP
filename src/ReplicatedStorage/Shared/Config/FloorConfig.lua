return {
    RecentRepeatWindow = 1,
    Floors = {
        {Id = "Archive", Template = "Hospital", Name = "Saint Orin / Containment Ward",
            Weight = 50, ObjectiveType = "Containment", Target = 5,
            Prompt = "Restore power, coordinate containment, and extract the archive.",
            Accent = Color3.fromRGB(92, 210, 202)},
        {Id = "Pelagic", Template = "FloodedLaboratory", Name = "Pelagic / Flooded Laboratory",
            Weight = 50, ObjectiveType = "Recovery", Target = 5,
            Prompt = "Restart the pumps, synchronize controls, and extract the specimen.",
            Accent = Color3.fromRGB(105, 168, 225)},
    },
}

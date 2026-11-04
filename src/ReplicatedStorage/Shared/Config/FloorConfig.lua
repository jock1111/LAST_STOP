return {
    RecentRepeatWindow = 1,
    Floors = {
        {Id = "Archive", Template = "Hospital", Name = "Saint Orin / Containment Ward",
            Weight = 40, ObjectiveType = "Containment", Target = 5,
            Prompt = "Restore power, coordinate containment, and extract the archive.",
            Accent = Color3.fromRGB(92, 210, 202)},
        {Id = "Pelagic", Template = "FloodedLaboratory", Name = "Pelagic / Flooded Laboratory",
            Weight = 35, ObjectiveType = "Recovery", Target = 5,
            Prompt = "Restart the pumps, synchronize controls, and extract the specimen.",
            Accent = Color3.fromRGB(105, 168, 225)},
        {Id = "Subway", Template = "AbandonedSubway", Name = "Abandoned Subway / The Last Train",
            Weight = 25, ObjectiveType = "Transit", Target = 5,
            Prompt = "Relay the signal, clear the rail, and reach the last train before the lights fail.",
            Accent = Color3.fromRGB(230, 170, 90)},
    },
}

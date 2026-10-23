{
  hours: [.days[:2][].hours[] | {
    time: .datetime, temperature, feel: .feeltemperature, icon: .iconcode, mm: .precipitationmm
  }],
  days: [.days[:6][] | {
    day: .date[:10], icon: .iconcode, min: .mintemperature, max: .maxtemperature, mm: .precipitationmm
  }]
}

/// Law identifier for Think and Solve handouts.
enum ThinkAndSolveLaw {
  boyles,
  charles,
  combined,
}

/// A section of handout content (title + body text).
class ThinkAndSolveSection {
  final String title;
  final String body;

  const ThinkAndSolveSection({required this.title, required this.body});
}

/// Sample problem data when the handout includes a worked example.
class ThinkAndSolveSampleProblem {
  final String problemStatement;
  final String given;
  final String? unknown;
  final String formula;
  final String solution;
  final String? interpretation;
  final String? finalAnswer;

  const ThinkAndSolveSampleProblem({
    required this.problemStatement,
    required this.given,
    this.unknown,
    required this.formula,
    required this.solution,
    this.interpretation,
    this.finalAnswer,
  });
}

/// Structured handout content for one law.
class ThinkAndSolveContent {
  final String screenTitle;
  final List<ThinkAndSolveSection> sections;
  final ThinkAndSolveSampleProblem? sampleProblem;

  const ThinkAndSolveContent({
    required this.screenTitle,
    required this.sections,
    this.sampleProblem,
  });
}

/// Content for all Think and Solve handouts (Boyle's, Charles's, Combined Gas Law).
class ThinkAndSolveContentProvider {
  static ThinkAndSolveContent getContent(ThinkAndSolveLaw law) {
    switch (law) {
      case ThinkAndSolveLaw.boyles:
        return _boylesContent;
      case ThinkAndSolveLaw.charles:
        return _charlesContent;
      case ThinkAndSolveLaw.combined:
        return _combinedContent;
    }
  }

  static const ThinkAndSolveContent _boylesContent = ThinkAndSolveContent(
    screenTitle: "Think and Solve (Boyle's Law)",
    sections: [
      ThinkAndSolveSection(
        title: 'Introduction',
        body: "In 1662, Robert Boyle first observed the relationship between the pressure (P) and volume (V) of a gas at constant temperature. He performed an experiment wherein he trapped a fixed amount of air in the J-tube, he changed the pressure and controlled the temperature and then, he observed its effect on the volume of the air inside the J-tube. He found out that as the pressure is increased, the volume decreases. He finally concluded that the volume of a fixed amount of gas is inversely proportional to the pressure at constant temperature.",
      ),
      ThinkAndSolveSection(
        title: 'Mathematical expression',
        body: "Mathematically, Boyle's law can be expressed as P ∝ 1/V.\n\nWhere P = pressure, V = volume, ∝ = proportionality sign. Replacing the proportionality sign with an equal sign: P = K₁(1/V), where K₁ is the proportionality constant. Furthermore, K₁ = PV.\n\nFor a given sample of gas under two different sets of conditions, at constant temperature: P₁V₁ = K = P₂V₂, or P₁V₁ = P₂V₂ [Boyle's Law Equation].\n\nWhere: P₁ = initial pressure, V₁ = initial volume; P₂ = final pressure, V₂ = final volume.",
      ),
    ],
    sampleProblem: ThinkAndSolveSampleProblem(
      problemStatement: "A fixed amount of gas occupies a syringe with a volume of 6.0 L. The pressure at 25°C is 1.00 atm. What will be the new pressure if the volume becomes 3.0 L at the same temperature?",
      given: "P₁ = 1.0 atm\nV₁ = 6.0 L\nV₂ = 3.0 L\nP₂ = ?",
      formula: "P₁V₁ = P₂V₂  ⇒  P₂ = P₁V₁ / V₂",
      solution: "P₂ = (1 atm)(6.0 L) / (3.0 L) = 2 atm",
      interpretation: "Based on the given, it is expected that the pressure should increase due to the decreasing amount of volume since pressure and volume are inversely proportional to each other.",
    ),
  );

  static const ThinkAndSolveContent _charlesContent = ThinkAndSolveContent(
    screenTitle: "Think and Solve (Charles's Law)",
    sections: [
      ThinkAndSolveSection(
        title: 'Introduction',
        body: "French physicist Jacques Charles (Jacques-Alexandre-César Charles, 1746–1823) studied the effect of temperature on the volume of a gas at constant pressure.",
      ),
      ThinkAndSolveSection(
        title: 'Experiment',
        body: "In his experiment, Jacques Charles trapped a sample of gas in a cylinder with a movable piston in a water bath at different temperatures. He found out that different gases decreased their volume by factors of 1/273 per °C of cooling. With this rate of reduction, if gas is cooled to −273°C, it would have zero volume—referred to as absolute zero, theoretically the lowest attainable temperature. This temperature is the zero point of the Kelvin (absolute) temperature scale. To convert °C to K, use: K = °C + 273.15.",
      ),
      ThinkAndSolveSection(
        title: 'Charles\'s Law',
        body: "Charles's Law states that at constant pressure, the volume of a fixed amount of gas is directly proportional to its absolute temperature. Mathematically: V = kT, where k is the constant for a fixed mass of gas. Since the volume-to-temperature ratio is constant for a given mass of gas at the same pressure: V₁/T₁ = V₂/T₂, or V₁T₂ = V₂T₁.\n\nWhere: V₁ = initial volume, V₂ = final volume, T₁ = initial temperature, T₂ = final temperature. Note that temperatures should be expressed in Kelvin.",
      ),
    ],
    sampleProblem: ThinkAndSolveSampleProblem(
      problemStatement: "Three liters of hydrogen at -20°C is allowed to warm to 27°C. What is the volume at this temperature if the pressure remains constant?",
      given: "V₁ = 3 L\nT₁ = -20°C + 273 = 253 K\nT₂ = 27°C + 273 = 300 K",
      unknown: "V₂ = ?",
      formula: "V₁/T₁ = V₂/T₂  ⇒  V₂ = V₁T₂ / T₁",
      solution: "V₂ = (3.00 L)(300 K) / 253 K",
      finalAnswer: "3.56 L",
    ),
  );

  static const ThinkAndSolveContent _combinedContent = ThinkAndSolveContent(
    screenTitle: 'Think and Solve (Combined Gas Law)',
    sections: [
      ThinkAndSolveSection(
        title: 'Kinetic Molecular Theory',
        body: "Kinetic Molecular Theory (KMT) describes why gases behave the way they do and explains the properties of gases.",
      ),
      ThinkAndSolveSection(
        title: "Boyle's Law and KMT",
        body: "Kinetic Molecular Theory can be used to explain both Boyle's and Charles's Laws. Boyle's law states that at constant temperature and amount of gas, pressure is inversely proportional to volume. Boyle's law is supported by the Kinetic Molecular Theory: when the volume of gas decreases, the rate at which gas molecules collide increases, and the pressure shoots up. Conversely, when the volume increases, the collision rate and the pressure drop.",
      ),
      ThinkAndSolveSection(
        title: "Charles's Law and KMT",
        body: "Charles's law states that, at constant pressure, volume is directly proportional to temperature. From kinetic theory, this is a reasonable relationship: an increase in temperature increases the average kinetic energy of the molecules. As the particles move faster, they hit the walls of the container more often. If the system is kept at constant pressure, the molecules must stay farther apart, and an increase in volume compensates for the increase in particle collisions with the surface of the container.",
      ),
    ],
    sampleProblem: null,
  );
}

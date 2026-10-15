namespace NutriExercise.Core.Configuration;

public static class BaselineKnowledge
{
    public static IReadOnlyList<BaselineKnowledgeDocument> Documents { get; } =
        new[]
        {
            new BaselineKnowledgeDocument(
                "ACSM Position Stand 2026",
                "ACSM",
                "Para optimizar la hipertrofia muscular, el volumen de entrenamiento debe ser de al menos 10 series semanales por grupo muscular. La carga puede variar entre el 30% y el 100% del 1RM siempre que las series se lleven cerca del fallo muscular."),
            new BaselineKnowledgeDocument(
                "Resistance Training Variables",
                "NIH Umbrella Review",
                "El descanso entre series para maximizar el crecimiento miofibrilar debe ser de 2 a 3 minutos para permitir la recuperación del sistema nervioso central. El entrenamiento al fallo es más crucial cuando se utilizan cargas ligeras."),
            new BaselineKnowledgeDocument(
                "Nutritional Supplements Evidence 2025",
                "PubMed Morphology",
                "Para hipertrofia, la ingesta de proteína óptima es de 1.6 g a 2.2 g por kilogramo de peso corporal al día. La creatina monohidrato (5g diarios) actúa como amplificador celular, mientras que el HMB es condicional.")
        };
}

public sealed record BaselineKnowledgeDocument(string Title, string Source, string Content);

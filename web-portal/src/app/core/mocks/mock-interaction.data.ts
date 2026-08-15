export interface Interaction {
  id: string;
  userPrompt: string;
  generatedRoutine: string;
  modelUsed: string;
  usedContext: string | null;
  isCorrect: boolean | null;
  userRating: number | null;
  createdAt: string;
}

export const mockInteractions: Interaction[] = [
  {
    id: '9b99b8b1-0001-4b5a-8f00-000000000001',
    userPrompt: 'Quiero ganar masa muscular en el pecho',
    generatedRoutine:
      'Rutina de pecho:\n1. Press banca 4x8-12\n2. Press inclinado 3x10-12\n3. Fondos 3x10\nDescansa 2-3 min entre series.',
    modelUsed: 'llama3-RAG',
    usedContext:
      'Para optimizar la hipertrofia muscular, el volumen de entrenamiento debe ser de al menos 10 series semanales por grupo muscular. La carga puede variar entre el 30% y el 100% del 1RM siempre que las series se lleven cerca del fallo muscular.',
    isCorrect: null,
    userRating: null,
    createdAt: new Date().toISOString(),
  },
  {
    id: '9b99b8b1-0002-4b5a-8f00-000000000002',
    userPrompt: 'Quiero aumentar proteína en mi dieta',
    generatedRoutine:
      'Aumenta la ingesta a 1.6-2.2 g/kg al día. Añade creatina monohidrato 5 g diarios para amplificar la respuesta celular.',
    modelUsed: 'llama3-RAG',
    usedContext:
      'Para hipertrofia, la ingesta de proteína óptima es de 1.6 g a 2.2 g por kilogramo de peso corporal al día. La creatina monohidrato (5g diarios) actúa como amplificador celular, mientras que el HMB es condicional.',
    isCorrect: true,
    userRating: 5,
    createdAt: new Date(Date.now() - 86400000).toISOString(),
  },
];

export type ConditionId = 'high-cholesterol' | 'type-2-diabetes' | 'gout';

export type EvaluationVerdict = 'RECOMMENDED' | 'NEUTRAL' | 'WARNING';

export interface MedicalCondition {
  id: ConditionId;
  name: string;
  severity: 'low' | 'moderate' | 'high';
  description: string;
}

export interface BaseNutrients {
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
}

export interface FoodItem {
  id: string;
  name: string;
  category: string;
  tags: string[];
  baseNutrients: BaseNutrients;
}

export interface UserProfile {
  id: string;
  displayName: string;
  age: number;
  conditionIds: ConditionId[];
  notes: string;
}

export interface AiSuggestion {
  id: string;
  text: string;
  context: ConditionId | 'general';
}

export interface EvaluatedFood {
  food: FoodItem;
  verdict: EvaluationVerdict;
  reason: string;
}

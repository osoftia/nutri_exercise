import { Component, input, output } from '@angular/core';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';

import { AiInteraction } from '../../../../core/models/interaction.model';
import { FeedbackForm } from '../feedback-form/feedback-form';

@Component({
  selector: 'app-routine-card',
  imports: [MatCardModule, MatChipsModule, FeedbackForm],
  templateUrl: './routine-card.html',
  styleUrl: './routine-card.scss',
})
export class RoutineCard {
  readonly interaction = input.required<AiInteraction>();
  readonly submitting = input(false);
  readonly feedbackSubmitted = output<{ id: string; text: string }>();

  onFeedback(text: string): void {
    this.feedbackSubmitted.emit({ id: this.interaction().id, text });
  }
}
import { Component, effect, inject, input, output } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';

@Component({
  selector: 'app-feedback-form',
  imports: [ReactiveFormsModule, MatFormFieldModule, MatInputModule, MatButtonModule],
  templateUrl: './feedback-form.html',
  styleUrl: './feedback-form.scss',
})
export class FeedbackForm {
  private readonly fb = inject(FormBuilder);

  readonly initialFeedback = input<string | null>(null);
  readonly submitting = input(false);
  readonly feedbackSubmitted = output<string>();

  readonly form: FormGroup = this.fb.nonNullable.group({
    feedback: ['', [Validators.required, Validators.maxLength(2000)]],
  });

  private readonly syncSavedFeedback = effect(() => {
    const saved = this.initialFeedback();
    if (saved === null) {
      return;
    }
    const control = this.form.controls['feedback'];
    if (control.value !== saved) {
      control.setValue(saved);
      control.markAsPristine();
    }
  });

  submit(): void {
    this.form.markAllAsTouched();
    if (this.form.invalid || this.submitting()) {
      return;
    }
    this.feedbackSubmitted.emit(this.form.controls['feedback'].value);
    this.form.markAsPristine();
  }
}
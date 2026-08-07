import { Component, input, model } from '@angular/core';

@Component({
  selector: 'app-form-input',
  imports: [],
  templateUrl: './form-input.html',
  styleUrl: './form-input.scss',
})
export class FormInput {
  readonly label = input('');
  readonly placeholder = input('');
  readonly type = input('text');
  readonly value = model('');
}

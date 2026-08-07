import { Component, model } from '@angular/core';
import { Icon } from '../../atoms/icon/icon';
import { FormInput } from '../../atoms/form-input/form-input';

@Component({
  selector: 'app-search-bar',
  imports: [Icon, FormInput],
  templateUrl: './search-bar.html',
  styleUrl: './search-bar.scss',
})
export class SearchBar {
  readonly query = model('');
}

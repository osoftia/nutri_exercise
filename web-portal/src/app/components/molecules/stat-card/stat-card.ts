import { Component, input } from '@angular/core';
import { Icon } from '../../atoms/icon/icon';

@Component({
  selector: 'app-stat-card',
  imports: [Icon],
  templateUrl: './stat-card.html',
  styleUrl: './stat-card.scss',
})
export class StatCard {
  readonly label = input('');
  readonly value = input('');
  readonly unit = input('');
  readonly trend = input<'up' | 'down'>('up');
}

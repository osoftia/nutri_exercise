import { Component, input, output } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

import { TelemetrySnapshot } from '../../../../core/models/analytics.model';

@Component({
  selector: 'app-mobile-usage',
  imports: [MatCardModule, MatProgressSpinnerModule, MatButtonModule],
  templateUrl: './mobile-usage.html',
  styleUrl: './mobile-usage.scss',
})
export class MobileUsage {
  readonly snapshot = input<TelemetrySnapshot | null>(null);
  readonly loading = input(false);
  readonly retry = output<void>();
}
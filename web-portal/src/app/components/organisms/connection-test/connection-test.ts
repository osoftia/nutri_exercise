import { Component, computed, inject, signal } from '@angular/core';

import { environment } from '../../../../environments/environment';
import { ConnectionState, HealthService } from '../../../core/services/health.service';
import { CustomButton } from '../../atoms/custom-button/custom-button';

@Component({
  selector: 'app-connection-test',
  imports: [CustomButton],
  templateUrl: './connection-test.html',
  styleUrl: './connection-test.scss',
})
export class ConnectionTest {
  private readonly health = inject(HealthService);

  readonly backendUrl = environment.backendUrl;
  readonly status = signal<ConnectionState>('idle');
  readonly detail = signal('');
  readonly latencyMs = signal<number | null>(null);

  readonly isChecking = computed(() => this.status() === 'checking');
  readonly headline = computed(() => {
    switch (this.status()) {
      case 'online':
        return 'ONLINE';
      case 'unreachable':
        return 'OFFLINE';
      case 'timeout':
        return 'TIMEOUT';
      case 'checking':
        return '…';
      default:
        return 'READY';
    }
  });

  testConnection(): void {
    if (this.isChecking()) return;
    this.status.set('checking');
    this.detail.set(`Contacting ${this.backendUrl} …`);
    this.latencyMs.set(null);
    this.health.checkConnection().subscribe({
      next: (result) => {
        this.status.set(result.state);
        this.detail.set(result.detail);
        this.latencyMs.set(result.latencyMs);
      },
      error: () => {
        this.status.set('unreachable');
        this.detail.set('Unexpected failure while contacting the backend.');
      },
    });
  }
}

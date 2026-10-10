import { Component, inject } from '@angular/core';

import { AuditLogStore } from '../../../core/stores/audit-log.store';
import { CustomButton } from '../../atoms/custom-button/custom-button';

@Component({
  selector: 'app-audit-log',
  imports: [CustomButton],
  templateUrl: './audit-log.html',
  styleUrl: './audit-log.scss',
})
export class AuditLog {
  readonly store = inject(AuditLogStore);
}

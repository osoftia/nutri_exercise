import { Component, input } from '@angular/core';

export interface DataTableColumn {
  key: string;
  label: string;
}

@Component({
  selector: 'app-data-table',
  imports: [],
  templateUrl: './data-table.html',
  styleUrl: './data-table.scss',
})
export class DataTable {
  readonly columns = input<DataTableColumn[]>([]);
  readonly rows = input<Record<string, unknown>[]>([]);
}

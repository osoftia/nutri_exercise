import { Component } from '@angular/core';
import { LanguageSwitcher } from '../../components/atoms/language-switcher/language-switcher';
import { ThemeSwitcher } from '../../components/atoms/theme-switcher/theme-switcher';
import { TranslatePipe } from '../../core/pipes/translate.pipe';

@Component({
  selector: 'app-settings-page',
  imports: [LanguageSwitcher, ThemeSwitcher, TranslatePipe],
  templateUrl: './settings.page.html',
  styleUrl: './settings.page.scss',
})
export class SettingsPage {}

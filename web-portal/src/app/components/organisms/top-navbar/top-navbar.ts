import { Component } from '@angular/core';
import { SearchBar } from '../../molecules/search-bar/search-bar';

@Component({
  selector: 'app-top-navbar',
  imports: [SearchBar],
  templateUrl: './top-navbar.html',
  styleUrl: './top-navbar.scss',
})
export class TopNavbar {}

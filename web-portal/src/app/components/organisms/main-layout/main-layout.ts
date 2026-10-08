import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { AdminSidebar } from '../admin-sidebar/admin-sidebar';
import { TopNavbar } from '../top-navbar/top-navbar';

@Component({
  selector: 'app-main-layout',
  imports: [AdminSidebar, TopNavbar, RouterOutlet],
  templateUrl: './main-layout.html',
  styleUrl: './main-layout.scss',
})
export class MainLayout {}

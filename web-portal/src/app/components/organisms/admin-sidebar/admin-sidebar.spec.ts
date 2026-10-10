import { describe, expect, it } from 'vitest';
import { AdminSidebar } from './admin-sidebar';

describe('AdminSidebar', () => {
  it('toggles its collapsed signal', () => {
    const sidebar = new AdminSidebar();

    expect(sidebar.isCollapsed()).toBe(false);
    sidebar.toggleCollapsed();
    expect(sidebar.isCollapsed()).toBe(true);
    sidebar.toggleCollapsed();
    expect(sidebar.isCollapsed()).toBe(false);
  });
});

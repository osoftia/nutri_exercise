import { DestroyRef, WritableSignal, signal } from '@angular/core';

export function observeWidth(
  element: HTMLElement,
  destroyRef: DestroyRef,
  fallback = 640,
): WritableSignal<number> {
  const width = signal(fallback);
  if (typeof ResizeObserver === 'undefined') {
    return width;
  }

  let frame = 0;
  const observer = new ResizeObserver((entries) => {
    const measured = entries[0]?.contentRect.width;
    if (measured === undefined) {
      return;
    }
    cancelAnimationFrame(frame);
    frame = requestAnimationFrame(() => {
      const next = Math.round(measured);
      if (next > 0 && Math.abs(next - width()) > 0.5) {
        width.set(next);
      }
    });
  });

  observer.observe(element);
  destroyRef.onDestroy(() => {
    cancelAnimationFrame(frame);
    observer.disconnect();
  });

  return width;
}

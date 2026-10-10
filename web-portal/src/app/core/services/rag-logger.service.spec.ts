import '@angular/compiler';
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { Injector, runInInjectionContext } from '@angular/core';

import { RagLoggerService } from './rag-logger.service';

describe('RagLoggerService', () => {
  let logger: RagLoggerService;

  beforeEach(() => {
    const injector = Injector.create({ providers: [RagLoggerService] });
    logger = runInInjectionContext(injector, () => injector.get(RagLoggerService));
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('is provided as a singleton without constructor dependencies', () => {
    expect(logger).toBeInstanceOf(RagLoggerService);
  });

  it('routes info() through console.info with the [RAG-INFO]: prefix', () => {
    const spy = vi.spyOn(console, 'info').mockImplementation(() => undefined);
    logger.info('query executed successfully.');
    expect(spy).toHaveBeenCalledWith('[RAG-INFO]: query executed successfully.');
  });

  it('routes error() through console.error with the [RAG-ERROR]: prefix', () => {
    const spy = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    logger.error('ingestion HTTP call failed.');
    expect(spy).toHaveBeenCalledWith('[RAG-ERROR]: ingestion HTTP call failed.');
  });

  it('forwards context for info()', () => {
    const spy = vi.spyOn(console, 'info').mockImplementation(() => undefined);
    logger.info('ingestion action completed.', { userId: 1 });
    expect(spy).toHaveBeenCalledWith('[RAG-INFO]: ingestion action completed.', { userId: 1 });
  });

  it('forwards context for error()', () => {
    const spy = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    logger.error('unexpected server response.', { status: 500 });
    expect(spy).toHaveBeenCalledWith('[RAG-ERROR]: unexpected server response.', { status: 500 });
  });

  it('never emits the info prefix on the error channel and vice versa', () => {
    const infoSpy = vi.spyOn(console, 'info').mockImplementation(() => undefined);
    const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    logger.info('ok');
    logger.error('boom');
    expect(infoSpy).toHaveBeenCalledTimes(1);
    expect(errorSpy).toHaveBeenCalledTimes(1);
    expect(infoSpy.mock.calls[0][0]).not.toContain('[RAG-ERROR]');
    expect(errorSpy.mock.calls[0][0]).not.toContain('[RAG-INFO]');
  });
});

import { WebPlugin } from '@capacitor/core';

import type {
  CapacitorMapboxNavigationPlugin,
  MapboxNavOptions, MapboxResult,
} from './definitions';

export class CapacitorMapboxNavigationWeb
  extends WebPlugin
  implements CapacitorMapboxNavigationPlugin
{
  async echo(options: { value: string }): Promise<{ value: string }> {
    return options;
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async show(_options: MapboxNavOptions): Promise<MapboxResult> {
    throw { status: 'failure', type: 'not_supported', data: 'navigation not supported on web' };
  }

  async history(): Promise<any> {
    throw { status: 'failure', type: 'not_supported', data: 'navigation not supported on web' };
  }

  async requestPermissions(): Promise<any> {
    throw { status: 'failure', type: 'not_supported', data: 'navigation not supported on web' };
  }

  async checkPermissions(): Promise<any> {
    throw { status: 'failure', type: 'not_supported', data: 'navigation not supported on web' };
  }
}

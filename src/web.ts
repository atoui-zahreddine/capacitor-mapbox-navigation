import { WebPlugin } from '@capacitor/core';

import type {
  CapacitorMapboxNavigationPlugin,
  MapboxNavOptions,
} from './definitions';

export class CapacitorMapboxNavigationWeb
  extends WebPlugin
  implements CapacitorMapboxNavigationPlugin
{
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }

  async show(options: MapboxNavOptions): Promise<void> {
    console.log('show', options);
  }

  async history(): Promise<any> {
    console.log('history');
  }

  async requestPermissions(): Promise<any> {
    console.log('requestPermissions');
  }

  async checkPermissions(): Promise<any> {
    console.log('checkPermissions');
  }
}

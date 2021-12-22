import { Injectable } from '@angular/core';

import { Storage } from '@ionic/storage-angular';

@Injectable({
  providedIn: 'root'
})
export class StorageService {
  private _storage: Storage | null = null;

  constructor(private storage: Storage) {
    this.init();
  }

  async init() {
    const storage = await this.storage.create();
    this._storage = storage;
    
    this.get("database-instance").then((value) => {
        if (!value) {
            this.resetToDefaults();
        }
    });
  }

  public set(key: string, value: any): Promise<any> {
    return this._storage?.set(key, value);
  }

  public get(key: string): Promise<any> {
    return this._storage?.get(key);
  }

  public resetToDefaults():void {
    this._storage.set("configuracoes", [
        {
            "id": 1,
            "periodoInicio": "05:00:00",
            "periodoTermino": "12:00:00",
            "assets": [  "sample-3s.mp3", "sample-9s.mp3", "sample-15s.mp3"]
        },
        {
            "id": 2,
            "periodoInicio": "12:30:00",
            "periodoTermino": "16:30:00",
            "assets": [ "sample-3s.mp3", "sample-9s.mp3", "sample-15s.mp3"]
        },
        {
            "id": 3,
            "periodoInicio": "16:40:00",
            "periodoTermino": "16:55:00",
            "assets": [  "sample-3s.mp3", "sample-9s.mp3", "sample-15s.mp3"]
        },
        {
            "id": 4,
            "periodoInicio": "17:00:00",
            "periodoTermino": "18:00:00",
            "assets": [  "sample-3s.mp3", "sample-9s.mp3", "sample-15s.mp3"]
        }
    ]);
  }
}

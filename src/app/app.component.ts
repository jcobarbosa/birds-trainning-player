import { Component } from '@angular/core';
import { BackgroundMode } from '@awesome-cordova-plugins/background-mode/ngx';
import { StorageService } from './storage-service';

@Component({
  selector: 'app-root',
  templateUrl: 'app.component.html',
  styleUrls: ['app.component.scss'],
})
export class AppComponent {
  public appPages = [
    { title: 'Player', url: '/player', icon: 'play' },
    { title: 'Configurações', url: '/setup', icon: 'setup' },
  ];

  constructor(private storage: StorageService,
              private backgroundMode: BackgroundMode) {

    this.backgroundMode.enable();
  }

  async ngOnInit() {

  }
}

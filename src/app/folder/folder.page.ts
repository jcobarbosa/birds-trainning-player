import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { NativeAudio } from '@ionic-native/native-audio/ngx';
import { StorageService } from '../storage-service';

@Component({
  selector: 'app-folder',
  templateUrl: './folder.page.html',
  styleUrls: ['./folder.page.scss'],
})
export class FolderPage implements OnInit {
  public folder: string;
  public name: string;

  constructor(
      private activatedRoute: ActivatedRoute,
      private nativeAudio: NativeAudio,
      private storage: StorageService) {

  }

  ngOnInit() {
    this.folder = this.activatedRoute.snapshot.paramMap.get('id');
    this.nativeAudio.preloadSimple('uniqueId1', 'assets/sound2.mp3');

  }

  playSingle() {
    this.nativeAudio.play('uniqueId1').then(() => {
      console.log('Successfully played');
    }).catch((err) => {
      console.log('error', err);
    });
  }

  save() {
    this.storage.set("nome", this.name);
  }

  get() {
    this.storage.get("nome").then((value) => {
      console.log(value);
      this.name = value;
    });
  }
}

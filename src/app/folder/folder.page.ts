import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { NativeAudio } from '@ionic-native/native-audio/ngx';

@Component({
  selector: 'app-folder',
  templateUrl: './folder.page.html',
  styleUrls: ['./folder.page.scss'],
})
export class FolderPage implements OnInit {
  public folder: string;

  constructor(private activatedRoute: ActivatedRoute, private nativeAudio: NativeAudio) { }

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
}

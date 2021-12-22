import { Component, OnInit } from '@angular/core';
import { BackgroundMode } from '@awesome-cordova-plugins/background-mode/ngx';
import { NativeAudio } from '@ionic-native/native-audio/ngx';
import { StorageService } from '../storage-service';

@Component({
  selector: 'app-player',
  templateUrl: './player.page.html',
  styleUrls: ['./player.page.scss'],
})
export class PlayerPage implements OnInit {
  public _musicas: any[];
  public _musicaAtual: string;
  public _periodos: any[];
  public _configuracoes: any[];
  public _configuracaoAtual: any;
  public _horario: string;

  constructor(private _storage: StorageService,
              private nativeAudio: NativeAudio,
              private backgroundMode: BackgroundMode) { }

  ngOnInit() {
    this._storage.get('configuracoes').then((configuracoes) => {
      this._configuracoes = configuracoes;
      this._configuracoes.forEach((configuracao) => {
        configuracao.assets.forEach((musica) => {
          this.nativeAudio.preloadSimple(musica, 'assets/' + musica);
        })
      });
    });

    this.iniciarMonitorHorario();
  }

  private iniciarMonitorHorario(): void {
    setInterval(() => {
      const agora = new Date();
      const horas = ('' + agora.getHours()).padStart(2, '0');
      const minutos = ('' + agora.getMinutes()).padStart(2, '0');
      const segundos = ('' + agora.getSeconds()).padStart(2, '0');
      this._horario = horas + ':' + minutos + ':' + segundos;
      const novaConfiguracao = this.capturarConfiguracaoDoHorario();

      if (!novaConfiguracao) {
        this._configuracaoAtual = null;
        if (this._musicaAtual) this.nativeAudio.stop(this._musicaAtual);
      } else {
        if (this._configuracaoAtual != novaConfiguracao) {
          this._configuracaoAtual = novaConfiguracao;
          if (this._musicaAtual) this.nativeAudio.stop(this._musicaAtual);
          this.tocarAsset();
        }
      }

    }, 1000);
  }

  monitorarHorario(executeThis): void {
    setTimeout(executeThis, 1000);
  }

  capturarConfiguracaoDoHorario(): any[] {
    return this._configuracoes.filter((configuracao) => 
        configuracao.periodoInicio < this._horario && configuracao.periodoTermino > this._horario
    )[0];
  }

  tocarAsset():void {
    if (this._configuracaoAtual.assetAtual >= 0) {
      let novaPosicao = this._configuracaoAtual.assetAtual + 1;
      if (novaPosicao < this._configuracaoAtual.assets.length) {
        this._configuracaoAtual.assetAtual = novaPosicao;
      } else {
        novaPosicao = 0;
      }
      this._musicaAtual = this._configuracaoAtual.assets[novaPosicao];
      this._configuracaoAtual.assetAtual = novaPosicao;
      this.tocar(this._configuracaoAtual.assets[novaPosicao]);
    } else {
      this._configuracaoAtual.assetAtual = 0;
      this._musicaAtual = this._configuracaoAtual.assets[this._configuracaoAtual.assetAtual];
      this.tocar(this._configuracaoAtual.assets[this._configuracaoAtual.assetAtual]);
    }
  }

  tocar(nomeMusica: string): void {
    this.backgroundMode.enable();
    this.backgroundMode.on("activate").subscribe(()=>{
      this.nativeAudio.play(nomeMusica, () => {
        this.tocarAsset();
      });
    });
    this.nativeAudio.play(nomeMusica, () => {
      this.tocarAsset();
    });
  }
}

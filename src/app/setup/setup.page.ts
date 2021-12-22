import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { TouchSequence } from 'selenium-webdriver';
import { StorageService } from '../storage-service';

@Component({
  selector: 'app-setup',
  templateUrl: './setup.page.html',
  styleUrls: ['./setup.page.scss'],
})
export class SetupPage implements OnInit {
  public _configuracoes: any[];

  constructor(private _storage: StorageService,
              private _router: Router) { }

  ngOnInit() {
    this._storage.get('configuracoes').then((configuracoes) => this._configuracoes = configuracoes);
  }

  salvar(): void {
    this._storage.set('configuracoes', this._configuracoes).then(() => this._router.navigate(['/player']));
  }
}

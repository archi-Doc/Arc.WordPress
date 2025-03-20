## 今まで

2012年からエックスサーバーを使用してWordPressサイトを構築していた。

費用も安く、使い方も簡単、性能も高いと、素晴らしいサービスだが、ずっと気になっていたのが多少なりともエックスサーバーに依存している点。

最近XServer VPSをお試しで使ってみたら、必要十分な機能がそろっていて、信じられないくらいコスパが良い。2GBプランなんて、現在（2025年3月）月額830円、キャッシュバックで415円。AWSのIPv4アドレス代より安いくらいだ。

そこで、エックスサーバーからXServer VPSに移転して、WordPress環境を再構築してみた。



## 考え方
私の（偏屈な）考え方としては、

- 可能な限り、何ものにも依存したくない。特定の企業・技術に依存することは可能な限り少なくしたい。となると、基本はLinux/OSS。
- 可搬性を最大限にしたい。AWSから出て行けと言われたら、風呂敷1枚にデータを入れて、明日から別の場所で同じ環境を再現できるようにしたい。

つまり **Minimum dependency, maximum portability** ということ。

それを踏まえてWordPressサイトを構築した。



## 構成
ファイルは[GitHub](https://github.com/archi-Doc/Arc.WordPress)で公開。

誰が考えても同じ結論になると思うが、基本はLinux+Docker Container/Composeで構成している。

クラウド時代の英語みたいなもの。

アーキテクチャ図は以下の通り。

![](https://github.com/archi-Doc/Arc.WordPress/blob/main/WordPress.png)

[sshh](https://github.com/archi-Doc/sshh)というのは、SSHを介してコンテナ環境にアクセスするためのコンテナ。

セキュリティリスクになるため注意が必要だが、簡単にコンテナ内にアクセスして、各種ファイルの編集や、cronによる自動処理（バックアップ等）ができる。

適当なDockerイメージがなかったため自作した（バカ）。

もっとスマートなやり方があったら教えてください。



DBのコンテナは1つ。

マイクロサービスの原則からすると、WordPressコンテナ毎にDBコンテナを作る方が良いらしいが、どのみちDBには個別にアクセスしないといけないのと、メモリー節約（DBコンテナ1つで200MB）のため一つにした。



## 手順

- インスタンスにDockerをインストール。

- ポート80(http), 443(https), 2222(sshh)を通す。

- `.env`ファイルを編集。

- 各種ファイルを`~/wordpress`にコピー。

- ```bash
  docker network create wordpress-network
  docker network create traefik-network
  docker compose up
  ```

- 必要に応じ**sshh**にアクセス（`ssh -i testkey.sk -p 2222 ubuntu@your.address`）し、`backup.sh` `restore.sh` を実行。



## 注意点

### VPSサーバー

メモリーが1GBだと厳しい。2GB以上が必須。

### ドメイン

ドメイン毎にWordPressコンテナやTraefikコンテナを割り当てている（`.env`）。

独自ドメインが必要。

### Htpasswd

[サイト](https://hostingcanada.org/htpasswd-generator/)で生成できるが、下記コードではエラーになるため、

`TRAEFIK_BASIC_AUTH=traefikadmin:$2y$10$HKGpmSJI25/d5QYUGXOOo.VU1q14.D5XHeQT6lQVQycynyPMTyvPq`

以下のように修正する。

`TRAEFIK_BASIC_AUTH=traefikadmin:$$2y$$10$$HKGpmSJI25/d5QYUGXOOo.VU1q14.D5XHeQT6lQVQycynyPMTyvPq`

### wp-config.php

httpsに統一したほうが良い。

sshhでコンテナ環境にアクセスし、

```bash
cd wp_1
sudo chmod 666 wp-config.php
vi wp-config.php
```

`wp-config.php`ファイルを編集。

```php
define( 'WP_HOME', 'http://' . $_SERVER['HTTP_HOST'] . '/' );
define( 'WP_SITEURL', 'http://' . $_SERVER['HTTP_HOST'] . '/' );
```

を

```php
if (empty($_SERVER['HTTPS'])) {
    $_SERVER['HTTPS'] = 'on'; $_ENV['HTTPS'] = 'on';
}
define( 'WP_HOME', 'https://' . $_SERVER['HTTP_HOST'] . '/' );
define( 'WP_SITEURL', 'https://' . $_SERVER['HTTP_HOST'] . '/' );
```

に変更して再起動する。

### wp-content/uploads

Restoreすると、権限が変更されてアップロードできなくなることがあった。

その場合は、以下のコマンドでwp-content/uploadsフォルダーを書き込み可能にする。

```bash
sudo chmod -R a+w  ~/wp_1/wp-content/uploads
```

### 自動処理

sshhのDocker composeで、以下の環境変数を設定できる（先頭の文字が一致すれば、複数設定可能）。

`StartupCommand`：コンテナ起動時に実行するコマンド。

`CronJob`：自動処理（cron）。

### MariaDBのデータベース作成

環境変数 `MARIADB_DATABASE`を設定すれば一発で作成できるが、複数データベースを作成することができない。

`entrypoint`でSQL処理を追加している。

単一のWordPressだけなら、 `MARIADB_DATABASE`を設定して、`entrypoint`を削除すればよい。


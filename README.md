## 001-aws-network
	- 内容：VPC-パブリックサブネットの構成です。
	  EC2などコンピューティングサービスは含まれていません。
	- ネットワーク解説：https://qiita.com/lamune-kiba-gaeru/items/1eda2ec71d2b872ab8a2

## 002-aws-network
	- 内容：VPC-パブリック-プライベートサブネットの構成です。
	  ALB、EC2、EIPなど料金が発生する構成が含まれています。
	- ネットワーク解説：https://qiita.com/lamune-kiba-gaeru/items/2abc6452d7e609bf6a49
	- 補足 EC2起動時のUserData説明
	  ALBからHTTPアクセスを行いたいため、EC2起動時にhttpdをインストール。
	  アクセス用のページを作成後にhttpdを起動する

## 003-aws-network
	- 内容：002の構成に追加でS3へのゲートウェイ型VPCエンドポイントと別VPCへのVPCピアリング接続の構成です。
	  ALB、EC2、EIP、インターフェース型エンドポイントなど料金が発生する構成が含まれています。
	- ネットワーク解説：https://qiita.com/lamune-kiba-gaeru/items/c7a262d3fb530882a77f
	- 今回からネストしたテンプレート構成となっております。ルートは「main」から始まるファイルとなります。
   	- EC2への接続にSSMを利用しています。その構成は以下の通り
		SSM接続する際に追加したインターフェースエンドポイント
			「com.amazonaws.region.ssm」
			「com.amazonaws.region.ec2messages」
			「com.amazonaws.region.ssmmessages」
		EC2インスタンスプロファイル
			AmazonSSMManagedInstanceCore
	- S3の制御について
		VPCエンドポイントのポリシーで絞っていますので、テンプレートから生成されたS3バケットのみアクセスが可能としてます。
			アクセスは「List」「Get」「Put」操作だけ。
		EC2インスタンスプロファイル
			S3の「List」「Get」「Put」だけ可能にしています。
	　- IPv6通信確認
		curl -g 'http://[通信先のIPv6アドレス]/'
	  - その他
 		CloudFormationのIPv6スタック削除の際にIPv6 Poolが原因で削除が止まります。
		その場合、「スタックの削除を強制」にして再度削除を行ってください。

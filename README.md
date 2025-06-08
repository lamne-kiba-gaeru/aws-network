## 001-aws-network
	- 内容：VPC-パブリックサブネットの構成です。
	  EC2などコンピューティングサービスは含まれていません。
	- ネットワーク解説：[AWS VPCネットワーク-パブリック構成](https://qiita.com/lamune-kiba-gaeru/items/1eda2ec71d2b872ab8a2)

## 002-aws-network
	- 内容：VPC-パブリック-プライベートサブネットの構成です。
	  ALB、EC2、EIPなど料金が発生する構成が含まれています。
	- ネットワーク解説：https://qiita.com/lamune-kiba-gaeru/items/2abc6452d7e609bf6a49
	- 補足 EC2起動時のUserData説明
	  ALBからHTTPアクセスを行いたいため、EC2起動時にhttpdをインストール。
	  アクセス用のページを作成後にhttpdを起動する

      


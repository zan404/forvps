<?
class AxisAPI
{
	//function untuk kirim otp
	function SendOTP($nomor){
		$url="https://wdcloudssh.net/api/new/axis/otp";
		$data=array("msisdn"=> $nomor);

		$curl = curl_init();
		curl_setopt($curl, CURLOPT_URL, $url);
		curl_setopt($curl, CURLOPT_POST, 1);
		curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
		curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
		$response = curl_exec($curl);
		return $response;
	}
	//function untuk login
	function sendLogin($nomor, $otp){
		$url="https://wdcloudssh.net/api/new/axis/login";
		$data=array("msisdn" => $nomor, "otp"=> $otp);

		$curl = curl_init();
		curl_setopt($curl, CURLOPT_URL, $url);
		curl_setopt($curl, CURLOPT_POST, 1);
		curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
		curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
		$response = curl_exec($curl);
		return $response;
	}
	// Fungsi buy package
	function getBuyPackageV2($token, $pkgid){
		$url="https://wdcloudssh.net/api/axis/package";
		$data=array("token"=> $token, "pkgid" => $pkgid);

		$curl = curl_init();
		curl_setopt($curl, CURLOPT_URL, $url);
		curl_setopt($curl, CURLOPT_POST, 1);
		curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
		curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
		$response = curl_exec($curl);
		return $response;
	}

	function getListPackageV2()
	{
		$curl = curl_init();
		curl_setopt_array($curl, array(
		CURLOPT_URL => 'https://wdcloudssh.net/api/axis/package/list',
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_ENCODING => '',
		CURLOPT_MAXREDIRS => 10,
		CURLOPT_TIMEOUT => 0,
		CURLOPT_FOLLOWLOCATION => true,
		CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
		CURLOPT_CUSTOMREQUEST => 'GET',
		));
		$response = curl_exec($curl);
		curl_close($curl);

		return $response;
	}

	function getBalance($auth)
	{
		$url="https://wdcloudssh.net/api/new/axis/getbalance";
		$data=array("token" => $auth);

		$curl = curl_init();
		curl_setopt($curl, CURLOPT_URL, $url);
		curl_setopt($curl, CURLOPT_POST, 1);
		curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
		curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
		$response = curl_exec($curl);
		return $response;
	}

	function authToken()
	{
		$authToken = fopen("auth.txt","r");
		$myAuth = fread($authToken,filesize("auth.txt"));
		fclose($authToken);
		return $myAuth;
	}
}

$yellow = "\033[33m";
$red = "\033[31m";
$blue = "\033[34m";
$White  = "\e[0;37m";
$Cyan   = "\e[0;36m";

$axis = new AxisAPI;
if (@fopen('auth.txt', 'r')) {
	$cek = $axis->getBalance(trim($axis->authToken()));
	$status = json_decode($cek, true);
	if ($status['status'] == true) {
		BuyPackage();
	}else {
		echo "$red ".$status['error_message'] . "\n";
		sleep(3);
		unlink("auth.txt");
		goto profile;
	}
}else{
	profile:
	echo "\n";
	echo "$blue ============================\n";
	echo "$White ⚙️ Author\t : ZAN404 \n";
	echo "$White ⚙️ Tanggal\t : ".date('Y-m-d')." \n";
	echo "$blue ============================\n";

	repeat_msisdn:
	echo "$yellow"."【+】Input Nomor Axis : ";
	$nomor = trim(fgets(STDIN));
	$response = $axis->SendOTP($nomor);
	$result = json_decode($response, true);
	if($result['status'] == true)
	{
		echo $blue . base64_decode($result['data']);
	}else{
		echo $red.$result['error_message'];
		echo "\n";
		goto repeat_msisdn;
	}
	echo "\n";

	repeat_otp:
	echo "$yellow"."【+】Input Kode OTP   : ";
	$otp = strtoupper(trim(fgets(STDIN)));
	$response = $axis->sendLogin($nomor, $otp);
	$result = json_decode($response, true);
	if($result['status'] == true)
	{
		$token = json_decode($result['data'], true);
		$file = fopen("auth.txt","w");
		$text = $token['token'];
		fwrite($file, $text);  
		fclose($file);
		echo "\n";
	}else{
		echo $red.$result['error_message'];
		echo "\n";
		goto repeat_otp;
	}
	echo "\n";
}

function BuyPackage()
{
	$Red      = "\e[0;31m";
	$Yellow = "\e[0;33m";
	$White  = "\e[0;37m";
	$Cyan   = "\e[0;36m";

	$axis = new AxisAPI;

	$getBalance = $axis->getBalance(trim($axis->authToken()));
	$result = json_decode($getBalance, true);
	$data = json_decode($result['data'], true);
	echo "$White ⚙️ No\t\t : " . "" .$data['msisdn']. "" . "\n";
	echo "$White ⚙️ Auth Token\t : " . "" . trim($axis->authToken()) . "" . "\n";
	echo "$White ⚙️ Balance\t : " . "Rp. ". number_format($data['result']['balance'], 0,',','.')."" . "\n";
	echo "$White ⚙️ Exp\t\t : " . "". $data['result']['activestopdate']."" . "\n\n";
        echo "$Yellow"."【+】Daftar Kuota Harian: \n";

	$daftar = $axis->getListPackageV2();
	$result = json_decode($daftar, true);
	foreach ($result['data'] as $list) {
		echo "$White"."$list \n";
	}

	echo "$Cyan"."【+】Choise Kuota Harian (Manual ID) : ";
	$choise = trim(fgets(STDIN));
	$pkgid = $axis->getBuyPackageV2(trim($axis->authToken()), $choise);
	$result = json_decode($pkgid, true);
	if ($result['status'] == true) {
		echo "$Cyan".$result['status_message']."\n";
	}else{
		echo "$Red".$result['status_message']."\n";
	}
}
repeat_quota:
echo "\n";
BuyPackage();
echo "\n";
echo "$Cyan"."【+】Tekan y untuk logout, Tekan n untuk mengulang pembelian kuota [y/N] : ";
$logout =  trim( fgets( STDIN ) );
if ( $logout !== 'y' ) {
	goto repeat_quota;
}
echo "\n";

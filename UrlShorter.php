<?php
/**
 * @file index.php
 * 
 * @brief Url shorter script
 * 
 * @details 
 * Use: 
 * - Place this script in root. Add an .htaccess file
 * - Make /.htaccess file:
 *       RewriteEngine on
 *       RewriteRule ^([a-zA-Z0-9]+)/?$ index.php?ShortTag=$1 [L,QSA]
 * - Create db
 *     - CREATE TABLE `history` (`his_id` int NOT NULL,  `his_st_id` int NOT NULL,  `his_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,  `his_info` longtext NOT NULL,  `his_fingerprint` varchar(240) NOT NULL,  `his_ip` varchar(120) NOT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
 *     - CREATE TABLE `shorttags` (`st_id` int NOT NULL,  `st_ucode` varchar(250) NOT NULL,  `st_url` varchar(250) NOT NULL,  `st_create` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,  `st_expire` timestamp NULL DEFAULT NULL) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
 *
 *
 * @author 		Jordi van Nistelrooij @ Webs en Systems. 
 * @email 		info@websensystems.nl
 * @website		https://websensystems.nl
 * @version 	1.0.0
 * @date 		2025-01-02
 * @copyright 	Non of these scripts maybe copied or modified without permission of the author
 * 
 */

?>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.7.1/jquery.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>
<?

$user="******"; //> Place DB Username
$pass="*****"; //> Place DB Password
$db="*****"; //> Place DB database

$mysqli = @new mysqli("localhost", $user, $pass, $db);
if($mysqli->connect_errno){
    exit("We have an db error!<br/>" . $mysqli->connect_errno);
}


function createUniqString(){
    $tokens = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    $tokens = $tokens.$tokens.$tokens;
    $outcome = str_shuffle($tokens);
    return substr($outcome,35,8);
}

if(isset($_REQUEST["Action"])){
    if($_REQUEST["Action"] = "Create"){
        $mysqli->query("INSERT INTO `shorttags` VALUES(NULL,'".$mysqli->real_escape_string($_REQUEST["shorttag"])."','".$mysqli->real_escape_string($_REQUEST["url"])."',CURRENT_TIMESTAMP,NULL)");
        echo "Created";
    }
}

if(isset($_REQUEST["ShortTag"])){
    if($_REQUEST["ShortTag"] == "Create"){
        $nieuw = createUniqString();
        echo "
            <form action=#>
                <input type=hidden name=Action value=Create /><br/>
                <input type=hidden name=shorttag value=". $nieuw." /><br/>
                https://linkkort.nl/".$nieuw."/<br/>
                <img style=width:300px src=https://api.qrserver.com/v1/create-qr-code/?data=https://linkkort.nl/".$nieuw."/&ecc=H&size=800x800&ecc=H /><br/>
                <input name=url placeholder=Link /><br/>
                <input type=submit value=Aanmaken />
            </form>
        ";
    }elseif($_REQUEST["ShortTag"] == "List"){
        $obj_result = $mysqli->query("SELECT * FROM `shorttags`");
        echo "<table class=table border=1>
                    <tr>
                        <td>ShortTag</td>
                        <td>QR</td>
                        <td>URL</td>
                        <td>Used</td>
                        <td>Last</td>
                    </tr>";
        while($arrST = $obj_result->fetch_assoc()){
            echo "
            <tr>
                <td>https://linkkort.nl/".$arrST["st_ucode"]."/</td>
                <td><img style=width:100px src=https://api.qrserver.com/v1/create-qr-code/?data=https://linkkort.nl/".$arrST["st_ucode"]."/&ecc=H&size=800x800&ecc=H /></td>
                <td>".$arrST["st_url"]."</td>
                <td>".$mysqli->query("SELECT * FROM `history` WHERE `his_st_id` = ".$arrST["st_id"]." ")->num_rows."</td>
                <td>".$mysqli->query("SELECT `his_timestamp` FROM `history` WHERE `his_st_id` = ".$arrST["st_id"]." ORDER BY `his_timestamp` DESC")->fetch_array()[0]."</td>
            </tr>
            ";
        }
        echo "</table>";
    }else{
        $obj_result = $mysqli->query("SELECT * FROM `shorttags` WHERE `st_ucode` LIKE '%".$mysqli->real_escape_string($_REQUEST["ShortTag"])."%'");
        if($obj_result->num_rows > 0){
            $arr_result = $obj_result->fetch_assoc();
            $arrFingerPrint[] = $_SERVER["REMOTE_HOST"];
            $arrFingerPrint[] = $_SERVER["REMOTE_ADDR"];
            $arrFingerPrint[] = $_SERVER["HTTP_USER_AGENT"];
            $arrFingerPrint[] = get_browser(null,true);
            $strFingerPrint = json_encode($arrFingerPrint);
            $MD5FingerPrint = md5($strFingerPrint);

            $mysqli->query("INSERT INTO `history` VALUES(NULL,".$arr_result["st_id"].",CURRENT_TIMESTAMP,'".$strFingerPrint."','".$MD5FingerPrint."','".$_SERVER["REMOTE_ADDR"]."')");
            header("Location: ".$arr_result["st_url"]);
        }
    }

    
}

?>
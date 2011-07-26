<?php
/****************************************************************************
* Copyleft meh. [http://meh.doesntexist.org | meh.ffff@gmail.com]           *
*                                                                           *
* This program is free software: you can redistribute it and/or modify      *
* it under the terms of the GNU General Public License as published by      *
* the Free Software Foundation, either version 3 of the License, or         *
* (at your option) any later version.                                       *
*                                                                           *
* This program is distributed in the hope that it will be useful,           *
* but WITHOUT ANY WARRANTY; without even the implied warranty of            *
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             *
* GNU General Public License for more details.                              *
*                                                                           *
* You should have received a copy of the GNU General Public License         *
* along with this program.  If not, see <http://www.gnu.org/licenses/>.     *
*****************************************************************************
* HASH cracker bruteforce + db                                              *
****************************************************************************/

/**
 * MySQL:
 * ---------
 * CREATE TABLE `hashes` (
 *     `hash` VARCHAR(128) NOT NULL,
 *     `text` TEXT         NOT NULL,
 *     `type` VARCHAR(23)  NOT NULL,
 *     
 *     PRIMARY KEY (`hash`),
 *             KEY (`type`),
 *
 *     UNIQUE `hash` (`hash`, `type`)
 * );
 */

@set_time_limit(0);

function getRequest ($name)
{
    if (!isset($_REQUEST[$name])) {
        return null;
    }

    return (get_magic_quotes_gpc() ? stripslashes($_REQUEST[$name]) : $_REQUEST[$name]);
}

$Config = array(
    'host'     => 'localhost',
    'username' => 'root',
    'password' => 'lolwut',
    'database' => 'hashes',
);

if (isset($_REQUEST['decrypt'])) {
    if (!function_exists('mysql_connect')) {
        echo 'You can crack the hash only with MySQL support.';
        exit;
    }

    mysql_connect($Config['host'], $Config['username'], $Config['password']);
    mysql_select_db($Config['database']);

    $Hash = mysql_real_escape_string(getRequest('hash'));
    $Type = mysql_real_escape_string(getRequest('type'));

    $Charset = ($_REQUEST['charset'] ? getRequest('charset')      : 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
    $Length  = ($_REQUEST['length']  ? (int) getRequest('length') : 42);
    $Fixed   = ($_REQUEST['fixed']   ? true                       : false);

    $query  = "SELECT * FROM `hashes` WHERE `hash` = '{$Hash}' AND `type` = '{$Type}'";
    $result = mysql_fetch_array(mysql_query($query), MYSQL_ASSOC);

    if ($result) {
        echo $result['text'];
        exit;
    }

    $query = "INSERT IGNORE INTO `hashes` VALUES('%HASH%', '%TEXT%', '{$Type}')";

    $CharsetLength = strlen($Charset);
    for ($length = ($Fixed ? $Length : 1); $length <= $Length; $length++) {
        $result = str_repeat($Charset[0], $length);
        $check  = array_fill(0, $length, 0);

        while (true) {
            $result[$length-1] = $Charset[++$check[$length-1]];

            for ($h = $length; $h > 1; $h--) {
                if ($check[$h-1] > $CharsetLength-1) {
                    $result[$h-2] = $Charset[++$check[$h-2]];
                    $check[$h-1]  = 0;
                    $result[$h-1] = $Charset[$check[$h-1]];
                }
            }

            $hash = hash($Type, $result);
            mysql_query(str_replace(array('%HASH%', '%TEXT%'), array_map('mysql_real_escape_string', array($hash, $result)), $query));

            if ($hash == $Hash) {
                break 2;
            }

            if (strstr($result, str_repeat($Charset[$CharsetLength-1], $length)) !== FALSE) {
                break;
            }
        }
    }

    if ($hash == $Hash) {
        echo $result;
    }
    else {
        echo "Couldn't crack the hash.";
    }
}
else if (isset($_REQUEST['crypt'])) {
    $Hash = hash($_REQUEST['type'], getRequest('text'));

    if (function_exists('mysql_connect')) {
        $Text = mysql_real_escape_string(getRequest('text'));
        $Type = mysql_real_escape_string(getRequest('type'));

        $query = "INSERT IGNORE INTO `hashes` VALUES('{$Hash}', '{$Text}', '{$Type}')";

        mysql_connect($Config['host'], $Config['username'], $Config['password']);
        mysql_select_db($Config['database']);

        mysql_query($query);
    }

    echo $Hash;
}
else {
    $hashes = '';
    foreach (hash_algos() as $hash) {
        $hashes .= '<option value="' . $hash . '">' . strtoupper($hash) . '</option>';
    }

    echo <<<HTML

<html>
<head>
    <title>Fail HASH</title>

    <script src="http://ajax.googleapis.com/ajax/libs/prototype/1.6.0.3/prototype.js"></script>
    <script src="http://ajax.googleapis.com/ajax/libs/scriptaculous/1.8.2/scriptaculous.js"></script>

    <style>
    * {
        padding: 0;
        margin: 0;
    }

    body {
        width: 100%;
        background: #171717;
        text-align: center;

        color: #717171;
        font-family: Verdana;
        overflow: hidden;
    }

    #container {
        width: 500px;
        margin-left: auto;
        margin-right: auto;
        margin-top: 20px;
        text-align: justify;
    }

    #menu {
        margin-bottom: 10px;
        border: 1px solid #1f1f1f;
        text-align: center;
        padding-bottom: 2px;
    }
    
    #menu a {
        color: #888888;
        font-size: 13px;
        text-decoration: none;
        font-weight: bold;
        padding-left: 2px;
        padding-right: 2px;
        cursor: crosshair;
    }

    #menu a:hover {
        color: #902727;
    }

    #result {
        height: 40px;
        border: 1px solid #1f1f1f;
        padding-left: 2px;
        padding-right: 2px;
        overflow: auto;
    }
    </style>

    <script>
    FailHASH = {
        crypt: function (obj, text, type) {
            obj.innerHTML = 'Loading...';

            new Ajax.Request("{$_SERVER['PHP_SELF']}?crypt", {
                method: 'post',

                parameters: {
                    text: text,
                    type: type,
                },

                onSuccess: function (http) {
                    obj.innerHTML = http.responseText;
                },

                onFailure: function () {
                    obj.innerHTML = "No. Go away.";
                },
            });
        },

        decrypt: function (obj, hash, type, charset, length, fixed) {
            obj.innerHTML = 'Loading...';

            new Ajax.Request("{$_SERVER['PHP_SELF']}?decrypt", {
                method: 'post',

                parameters: {
                    hash: hash,
                    type: type,
                    charset: charset,
                    length: length,
                    fixed: (fixed ? 'lol' : ''),
                },

                onSuccess: function (http) {
                    obj.innerHTML = http.responseText;
                },

                onFailure: function () {
                    obj.innerHTML = "No. Go away.";
                },
            });
        },
    };
    </script>
</head>
<body>

<div id="container">
    <div id="menu"><a href="#" onclick="$('decrypt').show(); $('crypt').hide();">Crack</a> # <a href="#" onclick="$('decrypt').hide(); $('crypt').show();">Hash</a></div>

    <div id="input">
        <div id="decrypt"><form onsubmit="FailHASH.decrypt($('result'), $('hash').value, $('crack_type').getElementsByTagName('option')[$('crack_type').selectedIndex].value, $('charset').value, $('length').value, $('fixed').checked); return false;">
            <table>
                <tr><td>Hash:</td><td><input type="text" id="hash"/> <select id="crack_type">{$hashes}</select></td></tr>
                <tr><td>Charset:</td><td><input type="text" id="charset"/></td></tr>
                <tr><td>Length:</td><td><input type="text" id="length"/> <input style="position: relative; top: 3px;" type="checkbox" id="fixed"/> <span style="position: relative; top: 2px;">Fixed</span></td></tr>
            </table>
            <br/>
            <input type="submit" value="Crack">
        </form></div>

        <div id="crypt" style="display: none"><form onsubmit="FailHASH.crypt($('result'), $('text').value, $('hash_type').getElementsByTagName('option')[$('hash_type').selectedIndex].value); return false;">
            <table>
                <tr><td>Text:</td><td><input type="text" id="text"/> <select id="hash_type">{$hashes}</select></td></tr>
            </table>
            <br/>
            <input type="submit" value="Hash">
        </form></div>
    </div>

    <div id="result"></div>
</div>

</body>
</html>

HTML;
}
?>

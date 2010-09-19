<?php
/****************************************************************************
* Copyleft meh. [http://meh.doesntexist.org | meh.ffff@gmail.com]           *
*                                                                           *
* This program is free software: you can redistribute it and/or modify      *
* it under the terms of the GNU Lesser General Public License as published  *
* by the Free Software Foundation, either version 3 of the License, or      *
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
* Sessions in database library.                                             *
****************************************************************************/

/**
 * MySQL:
 * ---------
 * CREATE TABLE `sessions` (
 *     `id`   VARCHAR(128) NOT NULL,
 *     `data` TEXT         NOT NULL,
 *     `time` DATETIME     NOT NULL,
 *     
 *     PRIMARY KEY (`id`),
 *
 *     UNIQUE `id` (`id`)
 * );
 */

class dbSession
{
    public static $Config = array(
        'host'     => 'localhost',
        'username' => 'root',
        'password' => 'lolwut',
        'database' => 'sessions'
    );

    public static $connection = null;

    public static function connect ()
    {
        if (!self::$connection || !mysql_ping(self::$connection)) {
            self::$connection = mysql_connect(self::$Config['host'], self::$Config['username'], self::$Config['password']);
        }
    
        mysql_select_db(self::$Config['database'], self::$connection);
    
        return self::$connection;
    }
    
    public static function open ($path, $name)
    {
        self::connect();
    
        return true;
    }
    
    public static function close ()
    {
        $db   = self::connect();
        $id   = mysql_real_escape_string(session_id());
        $data = mysql_real_escape_string(serialize($_SESSION));
    
        $query = "REPLACE INTO `sessions` VALUES('{$id}', '{$data}', NOW())";
        mysql_query($query, $db);
    }
    
    public static function read ($id)
    {
        $db = self::connect();
        $id = mysql_real_escape_string($id);
    
        $query  = "SELECT data FROM sessions WHERE `id` = '{$id}'";
        $query  = mysql_query($query, $db);
    
        if (!$query) {
            $result = serialize(array());
        }
        else {
            $result = mysql_fetch_array($query, MYSQL_ASSOC);
            $result = $result['data'];
        }
    
        $_SESSION = unserialize($result);
    
        return $result;
    }
    
    public static function write ($id, $data)
    {
        return true;
    }
    
    public static function destroy ($id)
    {
        $db = self::connect();
        $id = mysql_real_escape_string($id);
    
        $query = "DELETE FROM `sessions` WHERE `id` = '{$id}'";
        return (bool) mysql_query($query, $db);
    }
    
    public static function gc ($lifeTime)
    {
        $db = self::connect();
    
        $query  = "SELECT `id`, DATE_FORMAT(`time`, '%H=%i=%S=%m=%e=%Y') FROM `sessions`";
        $result = mysql_query($query);
    
        while ($session = mysql_fetch_array($result, MYSQL_ASSOC)) {
            $time = explode('=', $session['time']);
            $time = mktime($time[0], $time[1], $time[2], $time[3], $time[4], $time[5]) + $lifeTime;
    
            if ($time < time()) {
                $query = "DELETE FROM `sessions` WHERE `id` = '{$session['id']}'";
                mysql_query($query);
            }
        }
    
        return true;
    }
}
    
session_set_save_handler("dbSession::open", "dbSession::close", "dbSession::read", "dbSession::write", "dbSession::destroy", "dbSession::gc");
?>

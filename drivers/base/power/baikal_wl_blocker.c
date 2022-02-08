/*
 * Author: andip71, 28.08.2017
 *
 * Version 1.0.0
 *
 * This software is licensed under the terms of the GNU General Public
 * License version 2, as published by the Free Software Foundation, and
 * may be copied, distributed, and modified under those terms.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

/*
 * Change log:
 *
 * 1.0.0 (28.08.2017)
 *   - Initial version
 *
 */

#include <linux/module.h>
#include <linux/kobject.h>
#include <linux/sysfs.h>
#include <linux/device.h>
#include <linux/miscdevice.h>
#include <linux/printk.h>
#include <linux/pm_wakeup.h>


#define BAIKALOS_WL_BLOCKER_VERSION	"1.0.0"

static bool active=true;
module_param(active, bool, 0664);


const char *ws_list_eq[] = {
    "hal_bluetooth_lock",
    "NETLINK",
    "DIAG_WS",
    NULL
};


const char *ws_list_contains[] = {
    NULL
};

const char *ws_list_starts_with[] = {
    NULL
};

const char *ws_list_forced_eq[] = {
    "qcom_rx_wakelock",
    NULL
};




bool check_wakelock(struct wakeup_source *ws) {   
    int i;
    for( i=0;;i++ ) { 
        if( !ws_list_eq[i] ) break;
        if( !strcmp(ws_list_eq[i], ws->name) ) {
            ws->disabled = true;
            return true;
        }
    }
    
    for( i=0;;i++ ) { 
        if( !ws_list_contains[i] ) break;
        if( strstr(ws->name, ws_list_contains[i]) ) {
            ws->disabled = true;
            return true;
        }
    }
         
    for( i=0;;i++ ) { 
        if( !ws_list_starts_with[i] ) break;
        if( !strncmp(ws->name, ws_list_starts_with[i], strlen(ws_list_starts_with[i])) ) {
            ws->disabled = true;
            return true;
        }
    }
    

    for( i=0;;i++ ) { 
        if( !ws_list_forced_eq[i] ) break;
        if( !strcmp(ws_list_forced_eq[i], ws->name) ) {
            ws->forced = true;
            return false;
        }
    }

    return false;
}

bool is_wakelock_disabled(struct wakeup_source *ws) {
    if( !active && !ws) return false;
    return ws->disabled;
}

bool is_wakelock_forced(struct wakeup_source *ws) {
    if( !active && !ws) return false;
    return ws->forced;
}



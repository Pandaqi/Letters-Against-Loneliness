/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package javasimulation;

/**
 *
 * @author s148698
 */
class Vector3 {

    public int x;
    public int y;
    public int z;
    
    Vector3(int x, int y, int z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
    
    public boolean equalTo(Vector3 vec) {
        return (vec.x == x && vec.y == y && vec.z == z);
    }
}

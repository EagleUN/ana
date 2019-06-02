

const string SAMPLE_UUID = "dfcb2566-1a8d-4cb3-9f46-773adee5bfb4";

function isAlphanumeric(string s) returns boolean {
    return "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".contains(s);
}

public function isUuid(string s) returns boolean{
    if ( s.length() != SAMPLE_UUID.length() ) { return false; }
    foreach int i in 0...SAMPLE_UUID.length()-1 {
        if ( SAMPLE_UUID.substring(i,i+1) == "-" ) {
            if ( s.substring(i,i+1) != "-" ) {
                return false;
            }
        }
        else {
            if ( !isAlphanumeric(s.substring(i,i+1)) ) {
                return false;
            }
        }
    }
    return true;
}
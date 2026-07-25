import bcrypt from "bcrypt";

const password = "123456";

const generarHash = async () => {

    const hash = await bcrypt.hash(password, 10);

    console.log("Password:", password);
    console.log("Hash:", hash);

};

generarHash();
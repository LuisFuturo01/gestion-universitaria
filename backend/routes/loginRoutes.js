import express from "express";
import { login } from "../controllers/loginController.js";

const loginRutas = express.Router();

loginRutas.post("/", login);

export default loginRutas;
import { Router } from "express";
import { validate } from "../../middleware/validate.js";
import { idParams } from "../../shared/validation.js";
import { stockQuery } from "./stocks.validation.js";
import { listStocks } from "./stocks.service.js";

export const stocksRouter = Router();

stocksRouter.get(
  "/:id/stocks",
  validate({ params: idParams, query: stockQuery }),
  async (req, res) => {
    res.json(await listStocks(req.validated.params.id, req.validated.query));
  },
);

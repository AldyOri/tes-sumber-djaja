import { Router } from "express";
import { validate } from "../../middleware/validate.js";
import { idParams } from "../../shared/validation.js";
import { transferBody, transferQuery } from "./transfers.validation.js";
import * as service from "./transfers.service.js";

export const transfersRouter = Router();

transfersRouter.get(
  "/",
  validate({ query: transferQuery }),
  async (req, res) => {
    res.json(await service.listTransfers(req.validated.query));
  },
);

transfersRouter.get(
  "/:id",
  validate({ params: idParams }),
  async (req, res) => {
    res.json({ data: await service.getTransfer(req.validated.params.id) });
  },
);

transfersRouter.post(
  "/",
  validate({ body: transferBody }),
  async (req, res) => {
    res
      .status(201)
      .json({ data: await service.createTransfer(req.validated.body) });
  },
);

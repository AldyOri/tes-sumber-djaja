import { Router } from "express";
import { validate } from "../../middleware/validate.js";
import { idParams } from "../../shared/validation.js";
import { listQuery } from "../../shared/pagination.js";
import { warehouseBody } from "./warehouses.validation.js";
import * as service from "./warehouses.service.js";

export const warehousesRouter = Router();

warehousesRouter.get("/", validate({ query: listQuery }), async (req, res) => {
  res.json(await service.listWarehouses(req.validated.query));
});

warehousesRouter.post(
  "/",
  validate({ body: warehouseBody }),
  async (req, res) => {
    res
      .status(201)
      .json({ data: await service.createWarehouse(req.validated.body) });
  },
);

warehousesRouter.put(
  "/:id",
  validate({ params: idParams, body: warehouseBody }),
  async (req, res) => {
    res.json({
      data: await service.updateWarehouse(
        req.validated.params.id,
        req.validated.body,
      ),
    });
  },
);

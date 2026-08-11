from pydantic import BaseModel, Field


class SubscriptionPurchase(BaseModel):
    plan_id: str
    purchase_token: str = Field(min_length=8, max_length=200)


class CoinPurchase(BaseModel):
    package_id: str
    purchase_token: str = Field(min_length=8, max_length=200)


type EventOptions = {
	customFields: { [string]: string }?,
}

export type BusinessEventOptions = EventOptions & {
	amount: number,
	itemType: string,
	itemId: string,
	cartType: string?,
}

export type ResourceEventOptions = EventOptions & {
	flowType: number,
	currency: string,
	amount: number,
	itemType: string,
	itemId: string,
}

export type ProgressionEventOptions = EventOptions & {
	progressionStatus: number,
	progression01: string,
	progression02: string?,
	progression03: string?,
	score: number?,
}

export type DesignEventOptions = EventOptions & {
	eventId: string,
	value: number?,
}

export type ErrorEventOptions = EventOptions & {
	message: string,
	severity: number,
}

export type CustomDimension = string

export type ProductInfo = {
	Name: string,
	PriceInRobux: number,
}

export type ProcessReceiptInfo = {
	ProductId: number,
	PlayerId: number,
	CurrencySpent: number,
}

export type TeleportData = { [string]: any }
export type RemoteConfigs = { [string]: any }

export type GameAnalyticsOptions = {
	enableInfoLog: boolean?,
	enableVerboseLog: boolean?,
	availableCustomDimensions01: { CustomDimension }?,
	availableCustomDimensions02: { CustomDimension }?,
	availableCustomDimensions03: { CustomDimension }?,
	availableResourceCurrencies: { string }?,
	availableResourceItemTypes: { string }?,
	build: string?,
	availableGamepasses: { string }?,
	enableDebugLog: boolean?,
	automaticSendBusinessEvents: boolean?,
	reportErrors: boolean?,
	useCustomUserId: boolean?,
	gameKey: string?,
	secretKey: string?,
}

return {}
